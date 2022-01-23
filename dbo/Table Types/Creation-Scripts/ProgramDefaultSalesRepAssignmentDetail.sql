CREATE TYPE [dbo].[ProgramDefaultSalesRepAssignmentDetail] AS TABLE(
	[Type] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UploadFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[UploadFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[UploadFile_Content] [varbinary](82) NULL,
	[UploadDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[UploadById] [bigint] NULL,
	[ProgramDefaultSalesRepAssignmentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
