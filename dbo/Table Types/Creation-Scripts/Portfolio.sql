CREATE TYPE [dbo].[Portfolio] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[CollectionLoadBalancingMethod] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[CollectorCapacity] [bigint] NULL,
	[CollectionWorklistSortingOrder] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[WorklistHibernationDays] [int] NOT NULL,
	[ShowFollowUpsUpcomingIn] [bigint] NOT NULL,
	[MasterPortfolioId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
