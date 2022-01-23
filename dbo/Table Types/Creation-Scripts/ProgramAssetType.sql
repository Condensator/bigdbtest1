CREATE TYPE [dbo].[ProgramAssetType] AS TABLE(
	[IsUsageConditionRequired] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsModelYearRequired] [bit] NOT NULL,
	[ResidualMatrixAvailable] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[MaximumAllowedAge] [int] NOT NULL,
	[ApprovedTerm] [int] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[FeeTemplateId] [bigint] NULL,
	[ProgramDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
