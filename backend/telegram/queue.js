/**
 * Optimized Priority Queue for Telegram API & Storage Operations
 * Supports concurrent workers (pool) to prevent large uploads from blocking API calls,
 * with adaptive FloodWait backoff (429) protection.
 */
class TaskQueue {
  constructor(opsPerSecond = 25, maxConcurrent = 3) {
    this.opsPerSecond = Math.max(1, opsPerSecond);
    this.intervalMs = Math.floor(1000 / this.opsPerSecond);
    this.maxConcurrent = Math.max(1, maxConcurrent);
    this.activeWorkers = 0;
    this.queue = [];
    this.floodWaitUntil = 0;
    this.metrics = {
      processedCount: 0,
      floodWaitHits: 0,
      activeQueueLength: 0,
    };
  }

  /**
   * Enqueue a promise-returning task
   * @param {Function} taskFn - () => Promise<any>
   * @param {number} priority - Higher number = higher priority (e.g. 10 for chat, 8 for upload, 1 for background)
   * @returns {Promise<any>}
   */
  enqueue(taskFn, priority = 5) {
    return new Promise((resolve, reject) => {
      this.queue.push({
        taskFn,
        priority,
        resolve,
        reject,
        enqueuedAt: Date.now(),
      });

      // Sort queue by priority descending, then by time ascending
      this.queue.sort((a, b) => b.priority - a.priority || a.enqueuedAt - b.enqueuedAt);
      this.metrics.activeQueueLength = this.queue.length;

      this._drain();
    });
  }

  _drain() {
    while (this.activeWorkers < this.maxConcurrent && this.queue.length > 0) {
      const now = Date.now();
      if (this.floodWaitUntil > now) {
        const waitRemaining = this.floodWaitUntil - now;
        setTimeout(() => this._drain(), Math.min(waitRemaining, 5000));
        break;
      }
      this._runWorker();
    }
  }

  async _runWorker() {
    if (this.queue.length === 0) return;
    this.activeWorkers++;

    const item = this.queue.shift();
    this.metrics.activeQueueLength = this.queue.length;

    try {
      const result = await item.taskFn();
      this.metrics.processedCount++;
      item.resolve(result);
    } catch (err) {
      // Check for Telegram 429 FloodWait error
      if (err && err.response && err.response.error_code === 429) {
        this.metrics.floodWaitHits++;
        const retryAfterSeconds = (err.response.parameters && err.response.parameters.retry_after) || 5;
        this.floodWaitUntil = Date.now() + (retryAfterSeconds * 1000) + 500;
        console.warn(`[TaskQueue] Telegram FloodWait detected! Backing off for ${retryAfterSeconds}s`);
        // Re-insert task at the front of the queue
        this.queue.unshift(item);
      } else {
        item.reject(err);
      }
    } finally {
      this.activeWorkers--;
      setTimeout(() => this._drain(), this.intervalMs);
    }
  }

  getStats() {
    return {
      opsPerSecond: this.opsPerSecond,
      maxConcurrent: this.maxConcurrent,
      activeWorkers: this.activeWorkers,
      queueLength: this.queue.length,
      isFloodWaiting: Date.now() < this.floodWaitUntil,
      floodWaitRemainingMs: Math.max(0, this.floodWaitUntil - Date.now()),
      ...this.metrics,
    };
  }
}

module.exports = TaskQueue;
