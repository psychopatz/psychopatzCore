def run_gui() -> int:
    from .application import WorkshopApplication

    app = WorkshopApplication()
    app.mainloop()
    return 0
