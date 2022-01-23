CREATE TYPE [dbo].[DealProductType] AS TABLE(
	[Name] [nvarchar](32) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[GLSegmentValue] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalLeaseType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[LeaseType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DealTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
