CREATE TYPE [dbo].[NonVertexReceivableCodeDetail_Extract] AS TABLE(
	[ReceivableCodeId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NULL,
	[IsExemptAtReceivableCode] [bit] NOT NULL,
	[IsRental] [bit] NOT NULL,
	[IsCountryTaxExempt] [bit] NOT NULL,
	[IsStateTaxExempt] [bit] NOT NULL,
	[IsCountyTaxExempt] [bit] NOT NULL,
	[IsCityTaxExempt] [bit] NOT NULL,
	[TaxReceivableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[TaxTypeId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
