// Create Users
create user ff321;
create user ff322;

// Create session policies for 8 mins in UI and 10 mins for UI and tools
create session policy ff32p1
    SESSION_UI_IDLE_TIMEOUT_MINS = 8;
create session policy ff32p2
    SESSION_IDLE_TIMEOUT_MINS = 10;

// Set session policies to users
alter user ff321
    set session policy ff32p1;
alter user ff322
    set session policy ff32p2;
