CREATE TYPE [dbo].[TaxExemptionReasonConfig] AS TABLE(
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Reason] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
