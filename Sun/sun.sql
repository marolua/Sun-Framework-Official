SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- --------------------------------------------------------
-- Table `users`
-- --------------------------------------------------------

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `identifier` varchar(60) NOT NULL,
  `license` varchar(128) DEFAULT NULL,
  `charid` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `skin` longtext DEFAULT NULL,
  `position` longtext DEFAULT NULL,
  `job` varchar(50) NOT NULL DEFAULT 'unemployed',
  `job_grade` int(11) NOT NULL DEFAULT 0,
  `job_illegal` varchar(50) DEFAULT NULL,
  `job_illegal_grade` int(11) DEFAULT 0,
  `cash` bigint(20) NOT NULL DEFAULT 0,
  `bank` bigint(20) NOT NULL DEFAULT 0,
  `black_money` bigint(20) NOT NULL DEFAULT 0,
  `firstname` varchar(50) DEFAULT NULL,
  `lastname` varchar(50) DEFAULT NULL,
  `dateofbirth` varchar(25) DEFAULT NULL,
  `sex` varchar(10) DEFAULT NULL,
  `height` int(11) DEFAULT NULL,
  `group` varchar(50) NOT NULL DEFAULT 'user',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table `jobs`
-- --------------------------------------------------------

CREATE TABLE `jobs` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table `job_grades`
-- --------------------------------------------------------

CREATE TABLE `job_grades` (
  `id` int(10) UNSIGNED NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  `name` varchar(50) NOT NULL DEFAULT '',
  `label` varchar(100) NOT NULL DEFAULT '',
  `salary` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skin_male` longtext DEFAULT NULL,
  `skin_female` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table `owned_vehicle`
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `owned_vehicle` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL,
    `plate` VARCHAR(10) NOT NULL UNIQUE,
    `model` VARCHAR(64) NOT NULL,
    `stored` TINYINT(1) DEFAULT 1,
    INDEX `idx_identifier` (`identifier`)
);

-- --------------------------------------------------------
-- Index
-- --------------------------------------------------------

ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `identifier` (`identifier`),
  ADD KEY `license` (`license`),
  ADD KEY `job` (`job`),
  ADD KEY `created_at` (`created_at`);

ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

ALTER TABLE `job_grades`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `job_grade` (`job_name`,`grade`),
  ADD KEY `job_name` (`job_name`);

-- --------------------------------------------------------
-- AUTO_INCREMENT
-- --------------------------------------------------------

ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

ALTER TABLE `jobs`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

ALTER TABLE `job_grades`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;