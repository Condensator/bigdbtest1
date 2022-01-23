CREATE TYPE [dbo].[FinancialStatement] AS TABLE(
	[Frequency] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OtherStatementType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[StatementDate] [date] NOT NULL,
	[DaysToUpload] [int] NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[UploadByDate] [date] NOT NULL,
	[RAIDNumber] [int] NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
