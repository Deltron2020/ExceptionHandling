USE Database
GO

IF OBJECT_ID('dbo.tbl_ExceptionHandling') IS NOT NULL
BEGIN;
	DROP TABLE IF EXISTS dbo.tbl_ExceptionHandling
END;

CREATE TABLE dbo.tbl_ExceptionHandling
(	
	exception_id int not null identity(1, 1),
	client_id int null, -- your client identifier, for multi-tenant databases
	source_object_name varchar(255) null,
	source_server_name VARCHAR(255) NULL,
	source_db_name VARCHAR(255) NULL,
	source_error_line int null,
	system_error_number int null,
	exception_message varchar(2048) null,
	additional_info varchar(max) null,
	xml_data xml null,
	createdatetime datetime null
		constraint DF_exception_cdttm default (getdate()),
	createuser varchar(75) null
		constraint DF_exception_cusr default (suser_sname()),
	constraint PK_exception primary key nonclustered
	(
		exception_id asc
	)
);

GO

CREATE NONCLUSTERED INDEX idx_ExceptionHandling_createdatetime on dbo.tbl_ExceptionHandling
(
	createdatetime asc
)
include
(
	source_object_name
)
