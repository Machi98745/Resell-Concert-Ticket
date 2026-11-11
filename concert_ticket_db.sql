-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 11, 2026 at 09:47 AM
-- Server version: 10.11.16-MariaDB
-- PHP Version: 8.5.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `concert_ticket_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `concerts`
--

CREATE TABLE `concerts` (
  `concert_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `artist` varchar(100) DEFAULT NULL COMMENT 'ชื่อศิลปิน',
  `category` varchar(50) DEFAULT NULL COMMENT 'หมวด เช่น K-Pop, Pop, T-Pop',
  `description` text DEFAULT NULL,
  `venue` varchar(150) NOT NULL,
  `show_datetime` datetime NOT NULL,
  `poster_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `concerts`
--

INSERT INTO `concerts` (`concert_id`, `title`, `artist`, `category`, `description`, `venue`, `show_datetime`, `poster_url`, `created_at`) VALUES
(1, 'BODYSLAM EVERYBODYSLAM 2026', 'Bodyslam', 'T-Pop', 'คอนเสิร์ตใหญ่เต็มรูปแบบของ Bodyslam จัดเต็มแสงสีเสียง', 'Impact Arena Muang Thong Thani', '2026-12-15 19:00:00', 'https://via.placeholder.com/400x600?text=Bodyslam+2026', '2026-11-04 16:04:05'),
(2, 'THREE MAN DOWN LIVE IN BANGKOK', 'Three Man Down', 'T-Pop', 'คอนเสิร์ตรวมเพลงฮิต Three Man Down', 'Rajamangala National Stadium', '2026-12-20 18:30:00', 'https://via.placeholder.com/400x600?text=Three+Man+Down', '2026-11-04 16:04:05'),
(3, 'JEFF SATUR SPACE SHUTTLE CONCERT', 'Jeff Satur', 'T-Pop', 'คอนเสิร์ตเดี่ยวสุดอลังการของ Jeff Satur', 'UOB Live Bangkok', '2027-01-10 19:00:00', 'https://via.placeholder.com/400x600?text=Jeff+Satur', '2026-11-04 16:04:05');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `payment_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL COMMENT 'รายการขายต่อที่ซื้อ',
  `buyer_id` int(11) NOT NULL COMMENT 'ผู้ซื้อตั๋ว',
  `amount` decimal(10,2) NOT NULL COMMENT 'ยอดเงินที่ชำระ',
  `commission_fee` decimal(10,2) DEFAULT 0.00 COMMENT 'ค่าธรรมเนียมแพลตฟอร์ม 2%',
  `shipping_fee` decimal(10,2) DEFAULT 0.00 COMMENT 'ค่าจัดส่ง 50 บาท',
  `payment_method` enum('promptpay','credit_card','truemoney') NOT NULL,
  `delivery_method` varchar(50) NOT NULL DEFAULT 'delivery' COMMENT 'delivery, meetup, Parcel Shipping, Digital Transfer',
  `shipping_info` text DEFAULT NULL COMMENT 'ที่อยู่จัดส่ง หรือ สถานที่/เวลานัดรับบัตร',
  `shipping_status` varchar(50) DEFAULT 'Waiting for payment' COMMENT 'Waiting for payment, Preparing, Shipped, Delivered',
  `tracking_number` varchar(100) DEFAULT NULL COMMENT 'หมายเลขพัสดุ',
  `status` enum('pending','completed','failed','expired','cancelled') NOT NULL DEFAULT 'pending',
  `expires_at` datetime DEFAULT NULL COMMENT 'เวลาหมดอายุชำระเงิน (15 นาที)',
  `paid_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `resell_listings`
--

CREATE TABLE `resell_listings` (
  `listing_id` int(11) NOT NULL,
  `ticket_id` int(11) NOT NULL COMMENT 'ตั๋วที่นำมาลงขาย',
  `seller_id` int(11) NOT NULL COMMENT 'ผู้ขาย (customer)',
  `resell_price` decimal(10,2) NOT NULL COMMENT 'ราคาที่ตั้งขายต่อ',
  `delivery_type` varchar(50) DEFAULT 'Parcel Shipping' COMMENT 'Parcel Shipping หรือ Digital Transfer',
  `shipping_company` varchar(100) DEFAULT NULL COMMENT 'บริษัทขนส่ง หรือ ช่องทางโอนบัตร',
  `shipping_fee` decimal(10,2) DEFAULT 0.00 COMMENT 'ค่าจัดส่ง',
  `delivery_note` text DEFAULT NULL COMMENT 'หมายเหตุการจัดส่ง',
  `bank_name` varchar(100) DEFAULT NULL COMMENT 'ธนาคารรับเงินของผู้ขาย',
  `bank_account_name` varchar(150) DEFAULT NULL COMMENT 'ชื่อบัญชีผู้ขาย',
  `bank_account_number` varchar(50) DEFAULT NULL COMMENT 'เลขบัญชีผู้ขาย',
  `status` enum('available','sold','cancelled') NOT NULL DEFAULT 'available',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `resell_listings`
--

INSERT INTO `resell_listings` (`listing_id`, `ticket_id`, `seller_id`, `resell_price`, `delivery_type`, `shipping_company`, `shipping_fee`, `delivery_note`, `bank_name`, `bank_account_name`, `bank_account_number`, `status`, `created_at`) VALUES
(1, 1, 1, 4200.00, 'Parcel Shipping', NULL, 0.00, NULL, NULL, NULL, NULL, 'available', '2026-11-04 16:04:06'),
(2, 3, 3, 3300.00, 'Parcel Shipping', NULL, 0.00, NULL, NULL, NULL, NULL, 'available', '2026-11-04 16:04:06');

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `ticket_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL COMMENT 'เจ้าของตั๋วปัจจุบัน',
  `concert_id` int(11) NOT NULL COMMENT 'ตั๋วของคอนเสิร์ตไหน',
  `ticket_code` varchar(50) NOT NULL COMMENT 'รหัสหน้าบัตร',
  `zone_name` varchar(50) NOT NULL COMMENT 'ชื่อโซน เช่น VIP A1, Standing B',
  `seat_number` varchar(20) NOT NULL COMMENT 'เลขที่นั่ง เช่น A1-01 หรือ Standing',
  `original_price` decimal(10,2) NOT NULL COMMENT 'ราคาหน้าบัตรเดิม'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tickets`
--

INSERT INTO `tickets` (`ticket_id`, `user_id`, `concert_id`, `ticket_code`, `zone_name`, `seat_number`, `original_price`) VALUES
(1, 1, 1, 'TKT-BS2026-A101', 'VIP A1', 'A1-01', 4500.00),
(2, 1, 1, 'TKT-BS2026-A102', 'VIP A1', 'A1-02', 4500.00),
(3, 3, 2, 'TKT-TMD2026-S15', 'Zone S1', 'S1-15', 3500.00),
(6, 1, 1, 'TKT-TEST-999', 'VIP A1', 'A1-88', 4500.00),
(11, 1, 1, 'TKT-NEW-001', 'VIP A1', 'A1-55', 4500.00);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `role` enum('customer','admin') NOT NULL DEFAULT 'customer',
  `is_verified` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=ยังไม่ยืนยันคนจริง, 1=ยืนยันตัวตนแล้ว',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1=เปิดใช้งานปกติ, 0=ถูกระงับบัญชี',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `email`, `password_hash`, `full_name`, `phone`, `role`, `is_verified`, `is_active`, `created_at`) VALUES
(1, 'somchai01', 'somchai@email.com', '$argon2id$v=19$m=19456,t=2,p=1$8Uo8Fmyxnr62TGJ+OV71Wg$DQb+howOx5Lh9+cLShJTcgGnrNf4aNxiW4exYarhWPs', 'Somchai Jaidee (Verified Seller)', '0812345678', 'customer', 1, 1, '2026-11-04 16:04:05'),
(2, 'admin01', 'admin@tixxa.com', '$argon2id$v=19$m=19456,t=2,p=1$8Uo8Fmyxnr62TGJ+OV71Wg$DQb+howOx5Lh9+cLShJTcgGnrNf4aNxiW4exYarhWPs', 'Tixxa System Admin', '0800000000', 'customer', 1, 1, '2026-11-04 16:04:05'),
(3, 'somsak_unverified', 'somsak@email.com', '$argon2id$v=19$m=19456,t=2,p=1$8Uo8Fmyxnr62TGJ+OV71Wg$DQb+howOx5Lh9+cLShJTcgGnrNf4aNxiW4exYarhWPs', 'Somsak Newbie', '0891112222', 'customer', 0, 1, '2026-11-04 16:04:05');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `concerts`
--
ALTER TABLE `concerts`
  ADD PRIMARY KEY (`concert_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD KEY `listing_id` (`listing_id`),
  ADD KEY `buyer_id` (`buyer_id`);

--
-- Indexes for table `resell_listings`
--
ALTER TABLE `resell_listings`
  ADD PRIMARY KEY (`listing_id`),
  ADD KEY `ticket_id` (`ticket_id`),
  ADD KEY `seller_id` (`seller_id`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`ticket_id`),
  ADD UNIQUE KEY `ticket_code` (`ticket_code`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `concert_id` (`concert_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `concerts`
--
ALTER TABLE `concerts`
  MODIFY `concert_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `resell_listings`
--
ALTER TABLE `resell_listings`
  MODIFY `listing_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tickets`
--
ALTER TABLE `tickets`
  MODIFY `ticket_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `resell_listings` (`listing_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `resell_listings`
--
ALTER TABLE `resell_listings`
  ADD CONSTRAINT `resell_listings_ibfk_1` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`ticket_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `resell_listings_ibfk_2` FOREIGN KEY (`seller_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `tickets_ibfk_2` FOREIGN KEY (`concert_id`) REFERENCES `concerts` (`concert_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
