CREATE TYPE [dbo].[ReversalAssetLocationDetail_Extract] AS TABLE(
	[AssetLocationId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LocationEffectiveDate] [date] NOT NULL,
	[LienCredit] [decimal](16, 2) NOT NULL,
	[ReciprocityAmount] [decimal](16, 2) NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
