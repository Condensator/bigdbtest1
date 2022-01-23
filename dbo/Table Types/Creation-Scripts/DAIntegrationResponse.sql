CREATE TYPE [dbo].[DAIntegrationResponse] AS TABLE(
	[UniqueId] [uniqueidentifier] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EGN_CT] [varbinary](64) NULL,
	[NationalId_CT] [varbinary](64) NULL,
	[Reports] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[XMLResponse_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[XMLResponse_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[XMLResponse_Content] [varbinary](82) NULL,
	[ExceptionMessage] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
