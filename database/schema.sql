-- TRLM Letter Tracking & Analytics Dashboard schema

CREATE TABLE letters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sl_no VARCHAR(20) UNIQUE NOT NULL,
    letter_number VARCHAR(50) UNIQUE NOT NULL,
    subject TEXT NOT NULL,
    date_of_despatch DATE NOT NULL,
    deadline DATE NOT NULL,
    date_of_reply DATE NULL,
    status ENUM('Fast', 'On Time', 'Late', 'Waiting') DEFAULT 'Waiting',
    pdf_file_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    last_modified_by VARCHAR(100),
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL
);

CREATE TABLE letter_districts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    letter_id INT NOT NULL,
    district_name ENUM(
        'North Tripura',
        'Unakoti',
        'Dhalai',
        'Khowai',
        'West Tripura',
        'Sepahijala',
        'Gomati',
        'South Tripura'
    ) NOT NULL,
    district_reply_date DATE NULL,
    district_status ENUM('Fast', 'On Time', 'Late', 'Waiting') DEFAULT 'Waiting',
    FOREIGN KEY (letter_id) REFERENCES letters(id) ON DELETE CASCADE
);

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE activity_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action_type ENUM('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT') NOT NULL,
    letter_id INT NULL,
    action_details TEXT,
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (letter_id) REFERENCES letters(id) ON DELETE SET NULL
);
