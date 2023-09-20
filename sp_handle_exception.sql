USE Database
GO

if object_id('dbo.sp_handle_exception', 'P') is not null
	drop procedure dbo.sp_handle_exception
GO
/*
	Victor Ivantsov	created for SQL Saturday #1022 - this procedure makes it much easier to capture exceptions
	Modified & deployed by Tyler T on 9/13/23
*/
CREATE PROCEDURE dbo.sp_handle_exception
	@client_id INT = NULL,
	@source_procedure_id INT = 0,
	@additional_info VARCHAR(MAX) = NULL,
	@xml_data XML = NULL,
	@with_log BIT = 0
AS
begin
	---------------------------------------------------------------------------
	set nocount on;
	---------------------------------------------------------------------------
	if isnull(@source_procedure_id, 0) = 0 
		set @source_procedure_id = @@procid;
	---------------------------------------------------------------------------
	declare
		@error_number int = isnull(error_number(), @@error),
		-- very helpful debugging nested procedures calls
		@object_name nvarchar(255) = object_schema_name(@source_procedure_id) 
			+ N'.' + object_name(@source_procedure_id),
		@object_server_name NVARCHAR(255) = @@SERVERNAME,
		@error_severity int = isnull(error_severity(), 16),
		@error_state int = isnull(error_state(), 1),
		@error_line int = isnull(error_line(), 0),
		@current_db nvarchar(127) = db_name(),
		@error_message nvarchar(4000) = isnull(error_message(), N'NULL Error Message');
	---------------------------------------------------------------------------
	insert into dbo.ext_Martin_ExceptionHandling
	(
		client_id,
		source_object_name,
		source_server_name,
		source_db_name,
		source_error_line,
		system_error_number,
		exception_message,
		additional_info,
		xml_data
	)
	select
		@client_id as client_id,
		@object_name as source_object_name,
		@object_server_name AS source_server_name,
		@current_db AS source_db_name,
		@error_line as source_error_line,
		@error_number as system_error_number,
		left(@error_message, 2048) as exception_message,
		@additional_info as additional_info,
		@xml_data as xml_data;
	---------------------------------------------------------------------------
	declare
		@error_message_formatted nvarchar(4000) = @error_message + 
		', Error Line = %d, Server = %s, Database = %s, Procedure = %s';
	---------------------------------------------------------------------------
	if @with_log = 1
		raisError(@error_message_formatted, @error_severity, @error_state, 
			@error_line, @object_server_name, @current_db, @object_name) with log;
	else
		raisError(@error_message_formatted, @error_severity, @error_state, 
			@error_line, @object_server_name, @current_db, @object_name);
	------------------------------------------------------------------------------
	return @error_number;
	------------------------------------------------------------------------------
end 

GO