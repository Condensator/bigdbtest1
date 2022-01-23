CREATE TYPE [dbo].[QuoteRequest] AS TABLE(
	[Number] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LastRequestedDate] [date] NULL,
	[QuoteDate] [date] NOT NULL,
	[Status] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ProgramId] [bigint] NOT NULL,
	[ProgramVendorId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[ReasonofDeclineId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
