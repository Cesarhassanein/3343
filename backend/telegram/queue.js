/**
 * Rate-limited Priority Queue for Telegram API & Storage Operations
 * Protects against Telegram FloodWait and Too Many Requests (429)
 */
class TaskQueue {
  constructor(opsPerSecond = 25) {
    this.opsPerSecond = Math.max(1, opsPerSecond);
    this.intervalMs = Math.floor(1000 / this.opsPerSecond);
    this.queue = [];
    this.isProcessing = false;
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
   * @param {number} priority - Higher number = higher priority (e.g. 10 for chat, 1 for batch)
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

      if (!this.isProcessing) {
        this._processNext();
      }
    });
  }

  async _processNext() {
    if (this.queue.length === 0) {
      this.isProcessing = false;
      this.metrics.activeQueueLength = 0;
      return;
    }

    this.isProcessing = true;

    // Check if we are currently in a FloodWait backoff
    const now = Date.now();
    if (this.floodWaitUntil > now) {
      const waitRemaining = this.floodWaitUntil - now;
      setTimeout(() => this._processNext(), waitRemaining);
      return;
    }

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
    }

    setTimeout(() => this._processNext(), this.intervalMs);
  }

  getStats() {
    return {
      opsPerSecond: this.opsPerSecond,
      queueLength: this.queue.length,
      isFloodWaiting: Date.now() < this.floodWaitUntil,
      floodWaitRemainingMs: Math.max(0, this.floodWaitUntil - Date.now()),
      ...this.metrics,
    };
  }
}

module.exports = TaskQueue;
