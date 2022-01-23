CREATE TYPE [dbo].[LoanCustomAmort] AS TABLE(
	[UploadCustomAmort] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomAmortDocument_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CustomAmortDocument_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CustomAmortDocument_Content] [varbinary](82) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
