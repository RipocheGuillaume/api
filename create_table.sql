BEGIN;

-- Table Users
CREATE TABLE Users (
    id SERIAL PRIMARY KEY,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    birthdate DATE NOT NULL,
    avatar VARCHAR(200),
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trigger function to update updated_at on row update
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ language 'plpgsql';

-- Attach trigger to Users table
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON Users
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();


-- Table Publications
CREATE TABLE Publications (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    publication_date TIMESTAMP WITH TIME ZONE NOT NULL,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_publications_updated_at
BEFORE UPDATE ON Publications
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE INDEX IDX_Publications_User ON Publications(user_id);
CREATE INDEX IDX_Publications_Date ON Publications(publication_date);


-- Table Comments
CREATE TABLE Comments (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    comment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    publication_id INTEGER NOT NULL REFERENCES Publications(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_comments_updated_at
BEFORE UPDATE ON Comments
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE INDEX IDX_Comments_User ON Comments(user_id);
CREATE INDEX IDX_Comments_Publication ON Comments(publication_id);
CREATE INDEX IDX_Comments_Date ON Comments(comment_date);


-- Table UserGroups
CREATE TABLE UserGroups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    creation_date TIMESTAMP WITH TIME ZONE NOT NULL,
    creator_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_usergroups_updated_at
BEFORE UPDATE ON UserGroups
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE INDEX IDX_UserGroups_Creator ON UserGroups(creator_id);


-- Table GroupMembers
CREATE TABLE GroupMembers (
    id SERIAL PRIMARY KEY,
    join_date TIMESTAMP WITH TIME ZONE NOT NULL,
    member_status VARCHAR(20) NOT NULL,
    member_role VARCHAR(20) NOT NULL,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    group_id INTEGER NOT NULL REFERENCES UserGroups(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT UC_GroupMembers_UserGroup UNIQUE (user_id, group_id)
);

CREATE TRIGGER trg_groupmembers_updated_at
BEFORE UPDATE ON GroupMembers
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE INDEX IDX_GroupMembers_User ON GroupMembers(user_id);
CREATE INDEX IDX_GroupMembers_Group ON GroupMembers(group_id);
CREATE INDEX IDX_GroupMembers_Status ON GroupMembers(member_status);


-- Table Messages
CREATE TABLE Messages (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    send_date TIMESTAMP WITH TIME ZONE NOT NULL,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    group_id INTEGER NOT NULL REFERENCES UserGroups(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_messages_updated_at
BEFORE UPDATE ON Messages
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE INDEX IDX_Messages_User ON Messages(user_id);
CREATE INDEX IDX_Messages_Group ON Messages(group_id);
CREATE INDEX IDX_Messages_Date ON Messages(send_date);


-- Table Friendships
CREATE TABLE Friendships (
    id SERIAL PRIMARY KEY,
    creation_date TIMESTAMP WITH TIME ZONE NOT NULL,
    user1_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    user2_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT UC_Friendship_Users UNIQUE (user1_id, user2_id),
    CONSTRAINT CHK_Different_Users CHECK (user1_id <> user2_id),
    CONSTRAINT CHK_User_Order CHECK (user1_id < user2_id)
);

CREATE TRIGGER trg_friendships_updated_at
BEFORE UPDATE ON Friendships
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE INDEX IDX_Friendships_Users ON Friendships(user1_id, user2_id);


CREATE TABLE Events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    location VARCHAR(255),
    location_type VARCHAR(50),
    max_participants INTEGER,
    is_private BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) NOT NULL,
    creator_id INTEGER NOT NULL,
    group_id INTEGER,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Events_Creator FOREIGN KEY (creator_id)
        REFERENCES Users(id) ON DELETE CASCADE,
    CONSTRAINT FK_Events_Group FOREIGN KEY (group_id)
        REFERENCES UserGroups(id) ON DELETE SET NULL
);

CREATE INDEX idx_event_dates ON Events (start_date, end_date);
CREATE INDEX idx_event_status ON Events (status);

CREATE TABLE EventRSVPs (
    id SERIAL PRIMARY KEY,
    status VARCHAR(20) NOT NULL,
    response_date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    event_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_EventRSVPs_Event FOREIGN KEY (event_id)
        REFERENCES Events(id) ON DELETE CASCADE,
    CONSTRAINT FK_EventRSVPs_User FOREIGN KEY (user_id)
        REFERENCES Users(id) ON DELETE CASCADE,
    CONSTRAINT UC_EventRSVPs_EventUser UNIQUE (event_id, user_id)
);

CREATE INDEX idx_user_rsvps ON EventRSVPs (user_id, status);

CREATE TABLE SharedResources (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    resource_type VARCHAR(50) NOT NULL,
    path TEXT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size INTEGER NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    creator_id INTEGER NOT NULL,
    parent_id INTEGER,
    metadata JSON,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_SharedResources_Creator FOREIGN KEY (creator_id)
        REFERENCES Users(id) ON DELETE CASCADE,
    CONSTRAINT FK_SharedResources_Parent FOREIGN KEY (parent_id)
        REFERENCES SharedResources(id) ON DELETE CASCADE
);

CREATE INDEX idx_resource_type ON SharedResources (resource_type);
CREATE INDEX idx_creator_resources ON SharedResources (creator_id);

CREATE TABLE ResourceAccess (
    id SERIAL PRIMARY KEY,
    access_type VARCHAR(20) NOT NULL,
    granted_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,
    resource_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    granted_by_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_ResourceAccess_Resource FOREIGN KEY (resource_id)
        REFERENCES SharedResources(id) ON DELETE CASCADE,
    CONSTRAINT FK_ResourceAccess_User FOREIGN KEY (user_id)
        REFERENCES Users(id) ON DELETE CASCADE,
    CONSTRAINT FK_ResourceAccess_Grantor FOREIGN KEY (granted_by_id)
        REFERENCES Users(id) ON DELETE CASCADE,
    CONSTRAINT UC_ResourceAccess_ResourceUser UNIQUE (resource_id, user_id)
);

CREATE INDEX idx_user_access ON ResourceAccess (user_id);

CREATE TABLE EventResources (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL,
    resource_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_EventResources_Event FOREIGN KEY (event_id)
        REFERENCES Events(id) ON DELETE CASCADE,
    CONSTRAINT FK_EventResources_Resource FOREIGN KEY (resource_id)
        REFERENCES SharedResources(id) ON DELETE CASCADE,
    CONSTRAINT UC_EventResources UNIQUE (event_id, resource_id)
);

CREATE TYPE notification_type AS ENUM (
    'message', 'friend_request', 'event_invite', 'group_invite',
    'comment', 'like', 'share', 'mention', 'system'
);

CREATE TYPE notification_priority AS ENUM ('low', 'medium', 'high');

CREATE TABLE Notifications (
    id SERIAL PRIMARY KEY,
    type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    priority notification_priority NOT NULL DEFAULT 'medium',
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    action_url TEXT,
    recipient_id INTEGER NOT NULL,
    sender_id INTEGER,
    relation_id INTEGER,
    metadata JSON,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Notifications_Recipient FOREIGN KEY (recipient_id)
        REFERENCES Users(id) ON DELETE CASCADE,
    CONSTRAINT FK_Notifications_Sender FOREIGN KEY (sender_id)
        REFERENCES Users(id) ON DELETE SET NULL
);

CREATE INDEX idx_user_notifications ON Notifications (recipient_id, read, created_at);
CREATE INDEX idx_notification_type ON Notifications (type);

COMMIT;
