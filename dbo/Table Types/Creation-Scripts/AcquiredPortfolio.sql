CREATE TYPE [dbo].[AcquiredPortfolio] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Type] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionDate] [date] NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[AcquiredFromId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
