import threading


class LockSingleton:
    """
    Wrapper around [threading.Lock](https://docs.python.org/3/library/threading.html#lock-objects)
    for a singleton with the same signature (#acquire, #release, #locked)

    Adapted from: https://medium.com/analytics-vidhya/how-to-create-a-thread-safe-singleton-class-in-python-822e1170a7f6
    threading.Lock: https://docs.python.org/3/library/threading.html#lock-objects
    """
    _instance = None
    # _lock is used for ensuring only one instance of this singleton is instantiated
    # self.lock below is the lock exposed for external usage
    _lock = threading.Lock()

    def __new__(cls, *args, **kwargs):
        with cls._lock:
            # another thread could have created the instance
            # before we acquired the lock. So check that the
            # instance is still nonexistent.
            if not cls._instance:
                cls._instance = super(LockSingleton, cls).__new__(cls)
            return cls._instance

    def __init__(self):
        self.lock = threading.Lock()

    def acquire(self, blocking=True, timeout=-1):
        self.lock.acquire(blocking, timeout)

    def release(self):
        self.lock.release()

    def locked(self):
        return self.lock.locked()