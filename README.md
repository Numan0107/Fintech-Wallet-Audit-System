# Fintech Wallet & Audit Ledger System

Fintech uygulamaları için tasarlanmış; sıkı veri tutarlılığına, transactional güvenliğe ve veritabanı seviyesinde automated auditing mekanizmasına odaklanan yüksek performanslı bir backend sistemi.

## 🚀 Tech Stack
* **Backend:** .NET 9.0 Minimal API
* **Micro-ORM:** Dapper (Ham SQL kontrolü ve yüksek throughput için)
* **Database:** Microsoft SQL Server (SSMS 20)

## 💡 Key Architectural Features
* **ACID Transactions:** Para transferleri sırasında atomisliği sağlar, herhangi bir hata durumunda değişiklikleri otomatik olarak geri alır (rollback).
* **Concurrency & Race Condition Prevention:** Aynı anda gelen isteklerde eksi bakiye oluşmasını önlemek için `UPDLOCK` ve `ROWLOCK` mekanizmalarını kullanır.
* **Automated Audit Logging:** Trigger'lar (`AFTER INSERT`), uygulama katmanına ekstra yük bindirmeden immutable audit loglarını otomatik kaydeder.
* **Stored Procedures:** Temel business logic ve finansal hesaplamaları doğrudan veritabanı motorunun içinde yürütür.

## 📂 Database Schema
Tabloları, Stored Procedure'leri ve Trigger'ları içeren eksiksiz veritabanı kurulum kodu [database_schema.sql](database_schema.sql) dosyasında yer almaktadır.

## 🔌 API Endpoints
* `POST /api/transfer` - Cüzdanlar arası güvenli para transferini gerçekleştirir.
