CREATE TYPE [dbo].[CustomerBondRating] AS TABLE(
	[Agency] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AgencyCustomerName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AgencyCustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AsOfDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[BondRatingId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
