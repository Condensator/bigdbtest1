CREATE TYPE [dbo].[BookDepreciationEnMasseSetupDetail] AS TABLE(
	[CostBasis_Amount] [decimal](16, 2) NOT NULL,
	[CostBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Salvage_Amount] [decimal](16, 2) NOT NULL,
	[Salvage_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginDate] [date] NOT NULL,
	[EndDate] [date] NULL,
	[RemainingLifeInMonths] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[BookDepreciationEnMasseSetupId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
