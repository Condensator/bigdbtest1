CREATE TYPE [dbo].[CourtFiling] AS TABLE(
	[RecordStartDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CaseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[FilingDate] [date] NULL,
	[LegalRelief] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecordStatus] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsFromLegalRelief] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[CourtId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
