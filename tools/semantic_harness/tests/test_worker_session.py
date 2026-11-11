from __future__ import annotations

from threading import Event, Lock
import unittest

from tools.semantic_harness.core.worker_session import SessionClosedError, WorkerSession


class FakeWorker:
    def __init__(self, pid: int = 123) -> None:
        self.request_started = Event()
        self.release_request = Event()
        self.closed = Event()
        self._lock = Lock()
        self.close_calls = 0
        self.queued_calls = 0
        self.pid = pid

    def capabilities(self) -> dict[str, object]:
        return {"protocol": 1}

    def status(self) -> dict[str, object]:
        return {"pid": self.pid}

    def blocking_request(self) -> str:
        self.request_started.set()
        if not self.release_request.wait(timeout=3):
            raise TimeoutError("test request was not released")
        return "finished"

    def queued_request(self) -> str:
        with self._lock:
            self.queued_calls += 1
        return "should not run"

    def close(self) -> None:
        with self._lock:
            self.close_calls += 1
        self.closed.set()


class WorkerSessionTests(unittest.TestCase):
    def test_close_drains_queue_and_runs_worker_cleanup(self) -> None:
        worker = FakeWorker()
        session = WorkerSession(lambda: worker)
        self.addCleanup(session.close)
        self.addCleanup(worker.release_request.set)

        session.start().result(timeout=2)
        request = session.submit(lambda current: current.blocking_request())
        self.assertTrue(worker.request_started.wait(timeout=2))
        queued = session.submit(lambda current: current.queued_request())

        session.close()
        worker.release_request.set()

        self.assertEqual(request.result(timeout=2).value, "finished")
        with self.assertRaises(SessionClosedError):
            queued.result(timeout=2)
        self.assertTrue(worker.closed.wait(timeout=2))
        with worker._lock:
            self.assertEqual(worker.queued_calls, 0)
            self.assertEqual(worker.close_calls, 1)

    def test_close_while_starting_closes_late_worker(self) -> None:
        factory_entered = Event()
        release_factory = Event()
        worker = FakeWorker()

        def factory() -> FakeWorker:
            factory_entered.set()
            if not release_factory.wait(timeout=3):
                raise TimeoutError("test factory was not released")
            return worker

        session = WorkerSession(factory)
        self.addCleanup(session.close)
        self.addCleanup(release_factory.set)

        startup = session.start()
        self.assertTrue(factory_entered.wait(timeout=2))
        session.close()
        release_factory.set()

        with self.assertRaises(SessionClosedError):
            startup.result(timeout=2)
        self.assertTrue(worker.closed.wait(timeout=2))
        with worker._lock:
            self.assertEqual(worker.close_calls, 1)

    def test_reconfigure_closes_old_worker_and_keeps_session_queue(self) -> None:
        first = FakeWorker(pid=123)
        second = FakeWorker(pid=456)
        workers = iter((first, second))
        session = WorkerSession(lambda: next(workers))
        self.addCleanup(session.close)

        session.start().result(timeout=2)
        ready = session.reconfigure(lambda: next(workers)).result(timeout=2)

        self.assertEqual(ready.status["pid"], 456)
        self.assertTrue(first.closed.wait(timeout=2))
        self.assertEqual(
            session.submit(lambda current: current.status()["pid"])
            .result(timeout=2)
            .value,
            456,
        )


if __name__ == "__main__":
    unittest.main()
