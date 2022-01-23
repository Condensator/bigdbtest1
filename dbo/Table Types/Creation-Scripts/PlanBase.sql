CREATE TYPE [dbo].[PlanBase] AS TABLE(
	[PlanBasisNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PlanBasisDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[PlanBasisAbbreviation] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PlanBasisQuoteDocument_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[PlanBasisQuoteDocument_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PlanBasisQuoteDocument_Content] [varbinary](82) NULL,
	[PlanFamilyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
