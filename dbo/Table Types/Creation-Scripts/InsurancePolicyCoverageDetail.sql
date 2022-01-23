CREATE TYPE [dbo].[InsurancePolicyCoverageDetail] AS TABLE(
	[PerOccurrenceAmount_Amount] [decimal](16, 2) NOT NULL,
	[PerOccurrenceAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AggregateAmount_Amount] [decimal](16, 2) NOT NULL,
	[AggregateAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PerOccurrenceDeductible_Amount] [decimal](16, 2) NOT NULL,
	[PerOccurrenceDeductible_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AggregateDeductible_Amount] [decimal](16, 2) NOT NULL,
	[AggregateDeductible_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CoverageTypeConfigId] [bigint] NOT NULL,
	[InsurancePolicyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
