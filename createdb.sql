################
# PyTweet v0.1 #
################
#   Build DB   #
################

CREATE DATABASE IF NOT EXISTS PyTweet;

DROP TABLE IF EXISTS `PyTweet`.`tbl_user`;
CREATE TABLE `PyTweet`.`tbl_user` (
	`user_id` BIGINT NOT NULL AUTO_INCREMENT,
	`user_email` VARCHAR(254) NOT NULL,
  `user_firstname` VARCHAR(35) NOT NULL,
	`user_lastname` VARCHAR(35) NOT NULL,
	`user_password` VARCHAR(70) NOT NULL,
	PRIMARY KEY (`user_id`)
);

DROP TABLE IF EXISTS `PyTweet`.`tbl_post`;
CREATE TABLE `PyTweet`.`tbl_post` (
    `post_id` BIGINT NOT NULL AUTO_INCREMENT,
		`post_type` TINYINT NOT NULL,
    `post_text` VARCHAR(500) DEFAULT NULL,
    `post_user_id` BIGINT DEFAULT NULL,
    `post_date` DATETIME DEFAULT NULL,
    `post_img_path` VARCHAR(200) NULL,
    PRIMARY KEY (`post_id`)
) AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `PyTweet`.`tbl_likes`;
CREATE TABLE `PyTweet`.`tbl_likes` (
    `post_id` BIGINT NOT NULL,
    `like_id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NULL,
    `post_like` TINYINT NULL DEFAULT 0,
    PRIMARY KEY (`like_id`)
);

DROP TABLE IF EXISTS `PyTweet`.`tbl_relationships`;
CREATE TABLE `PyTweet`.`tbl_relationships` (
		`relationship_id` BIGINT NOT NULL AUTO_INCREMENT,
		`user_one_id` BIGINT NOT NULL,
		`user_two_id` BIGINT NOT NULL,
		PRIMARY KEY (`relationship_id`),
		UNIQUE KEY `ix_relationships` (`user_one_id`, `user_two_id`)
) Engine = InnoDB;

#############
# Functions #
#############

# Function to sum the total likes for posts
DROP FUNCTION IF EXISTS `PyTweet`.`getSum`;
USE `PyTweet`;
DELIMITER $$
CREATE FUNCTION `getSum` (
    p_post_id BIGINT
) RETURNS BIGINT
BEGIN
    SET @likesum = 0;
    SELECT SUM(post_like) INTO @likesum FROM tbl_likes WHERE post_id = p_post_id;
RETURN @likesum;
END$$
DELIMITER ;

# Function to determine if a user has liked a post
DROP FUNCTION IF EXISTS `PyTweet`.`hasLiked`;
USE `PyTweet`;
DELIMITER $$
CREATE FUNCTION `hasLiked` (
    p_post_id BIGINT,
    p_user_id BIGINT
) RETURNS TINYINT
BEGIN
    SET @likestatus = 0;
    SELECT post_like INTO @likestatus FROM tbl_likes WHERE post_id = p_post_id and user_id = p_user_id;
RETURN @likestatus;
END$$
DELIMITER ;

##############
# Procedures #
##############

# Procedure for creating a user from passed in data
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_createUser`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_createUser`(
	IN p_email VARCHAR(254),
	IN p_firstname VARCHAR(35),
	IN p_lastname VARCHAR(35),
	IN p_password VARCHAR(70)
)
BEGIN
    # Check whether the user already exists
	IF (SELECT EXISTS (SELECT 1 FROM tbl_user WHERE user_email = p_email) ) THEN

		SELECT 'Email Address Already Registered!';

	ELSE

		INSERT INTO tbl_user
		(
			user_email,
			user_firstname,
			user_lastname,
			user_password
		)
		VALUES
		(
			p_email,
			p_firstname,
			p_lastname,
			p_password
		);

	END IF;
END$$
DELIMITER ;

# Procedure for validating user login
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_validateLogin`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_validateLogin`(IN p_email VARCHAR(254)
)
BEGIN
    SELECT * FROM tbl_user WHERE user_email = p_email;
END$$
DELIMITER ;

# Procedure to add a new post
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_newPost`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_newPost`(
    IN p_type TINYINT,
    IN p_text VARCHAR(500),
    IN p_user_id BIGINT,
    IN p_img_path VARCHAR(200)
)
BEGIN
    INSERT INTO tbl_post(
        post_type,
        post_text,
        post_user_id,
        post_date,
        post_img_path
    )
    VALUES(
        p_type,
        p_text,
        p_user_id,
        NOW(),
        p_img_path
    );

    SET @last_id = LAST_INSERT_ID();

    INSERT INTO tbl_likes(
        post_id,
        user_id,
        post_like
    )
    VALUES(
        @last_id,
        p_user_id,
        0
    );

END$$
DELIMITER ;

# Procedure to retrieve all posts by a user
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_getPostByUser`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_getPostByUser` (
    IN p_user_id BIGINT
)
BEGIN
    SELECT * FROM tbl_post WHERE post_user_id = p_user_id;
END$$
DELIMITER ;

# Procedure to retrieve a post by its post ID and the userID
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_getPostByID`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_getPostByID` (
    IN p_post_id BIGINT,
    IN p_user_id BIGINT
)
BEGIN
SELECT * FROM tbl_post WHERE post_id = p_post_id and post_user_id = p_user_id;
END$$
DELIMITER ;

# Procedure to update a post
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_updatePost`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_updatePost` (
    IN p_title VARCHAR(45),
    IN p_description VARCHAR(500),
    IN p_post_id BIGINT,
    IN p_user_id BIGINT,
    IN p_file_path VARCHAR(200)
)
BEGIN
UPDATE tbl_post SET
    post_title = p_title,
    post_description = p_description,
    post_file_path = p_file_path
    WHERE post_id = p_post_id and post_user_id = p_user_id;
END$$
DELIMITER ;

# Procedure to delete posts
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_deletePost`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_deletePost` (
    IN p_post_id BIGINT,
    IN p_user_id BIGINT
)
BEGIN
    DELETE from tbl_post where post_id = p_post_id and post_user_id = p_user_id;
END$$
DELIMITER ;

# Procedure to get all posts
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_getAllPosts`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_getAllPosts` (
    IN p_user_id BIGINT
)
BEGIN
    SELECT post_id, post_text, post_user_id  FROM tbl_post;
END$$
DELIMITER ;

# Procedure to add/update post likes
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_AddUpdateLikes`;
USE `PyTweet`
DELIMITER $$
CREATE PROCEDURE `sp_AddUpdateLikes` (
    p_post_id BIGINT,
    p_user_id BIGINT,
    p_like TINYINT
)
BEGIN
    # Update existing like entry if it exists
    IF (SELECT EXISTS (SELECT 1 FROM tbl_likes WHERE post_id = p_post_id AND user_id = p_user_id)) THEN

        # Get current like value
        SELECT post_like INTO @curval FROM tbl_likes WHERE post_id = p_post_id AND user_id = p_user_id;

        # Toggle like value
        IF @curval = 0 THEN
            UPDATE tbl_likes SET post_like = 1 WHERE post_id = p_post_id AND user_id = p_user_id;
        ELSE
            UPDATE tbl_likes SET post_like = 0 WHERE post_id = p_post_id AND user_id = p_user_id;
        END IF;

    ELSE

        INSERT INTO tbl_likes(
            post_id,
            user_id,
            post_like
        )
        VALUES(
            p_post_id,
            p_user_id,
            p_like
            );

    END IF;
END$$
DELIMITER ;

# Procedure to retrieve post like status
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_getLikeStatus`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_getLikeStatus` (
    IN p_post_id BIGINT,
    IN p_user_id BIGINT
)
BEGIN
    SELECT getSum(p_post_id), hasLiked(p_post_id, p_user_id);
END$$
DELIMITER ;

# Procedure for creating a relationship
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_createRelationship`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_createRelationship`(
	IN p_user_one_id BIGINT,
	IN p_user_two_id BIGINT
)
BEGIN
	INSERT INTO tbl_relationships
	(
		user_one_id,
		user_two_id
	)
	VALUES
	(
		p_user_one_id,
		p_user_two_id
	);
END$$
DELIMITER ;

# Function for removing a relationship
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_removeRelationship`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_removeRelationship` (
	IN p_user_one_id BIGINT,
	IN p_user_two_id BIGINT
)
BEGIN
	DELETE FROM tbl_relationships WHERE user_one_id = p_user_one_id AND user_two_id = p_user_two_id;
	DELETE FROM tbl_relationships WHERE user_two_id = p_user_one_id AND user_one_id = p_user_two_id;
END$$
DELIMITER ;

# Function for getting a list of a users friends
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_getFriends`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_getFriends` (
	IN p_user_id BIGINT
)
BEGIN
	SELECT * FROM tbl_relationships WHERE user_one_id = p_user_id OR user_two_id = p_user_id;
END$$
DELIMITER ;

# Function for checking friendship relationship
DROP PROCEDURE IF EXISTS `PyTweet`.`sp_checkFriend`;
USE `PyTweet`;
DELIMITER $$
CREATE PROCEDURE `sp_checkFriend` (
	IN p_user_one_id BIGINT,
	IN p_user_two_id BIGINT
)
BEGIN
	SELECT * FROM tbl_relationships WHERE user_one_id = p_user_one_id AND user_two_id = p_user_two_id;
END$$
DELIMITER ;
