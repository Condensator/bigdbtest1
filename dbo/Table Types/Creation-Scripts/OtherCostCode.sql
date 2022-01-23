CREATE TYPE [dbo].[OtherCostCode] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityType] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[AllocationMethod] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsPrepaidUpfrontTax] [bit] NOT NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[PayableCodeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[CostTypeId] [bigint] NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
