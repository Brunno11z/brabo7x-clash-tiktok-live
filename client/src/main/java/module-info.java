module client {
    requires javafx.fxml;
    requires javafx.controls;
    requires core;
    requires java.net.http;

    opens controllers;
    opens controllers.menus;
    opens controllers.modes;
    opens controllers.authentication;
    opens controllers.modes.botControllers;
    opens controllers.modes.onlineControllers;
    opens controllers.modes.runnables;
    opens interactive;

    exports controllers;
    exports interactive;
    exports controllers.menus;
    exports controllers.modes;
    exports globals;
}
