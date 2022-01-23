CREATE TYPE [dbo].[PropertiesInformationForCreditDecision] AS TABLE(
	[Number] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Property] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[RelatedActs] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[RegistryAgency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Location] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[m2] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreditDecisionForCreditApplicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
