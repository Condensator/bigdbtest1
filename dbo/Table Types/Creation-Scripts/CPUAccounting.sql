CREATE TYPE [dbo].[CPUAccounting] AS TABLE(
	[BaseFeePayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OverageFeePayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[LineofBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[BaseFeeReceivableCodeId] [bigint] NULL,
	[OverageFeeReceivableCodeId] [bigint] NULL,
	[BaseFeePayableCodeId] [bigint] NULL,
	[OverageFeePayableCodeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
