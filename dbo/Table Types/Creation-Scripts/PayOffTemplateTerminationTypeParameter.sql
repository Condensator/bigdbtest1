CREATE TYPE [dbo].[PayOffTemplateTerminationTypeParameter] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ApplicableForFixedTerm] [bit] NOT NULL,
	[DiscountRate] [decimal](8, 4) NULL,
	[Factor] [decimal](8, 4) NULL,
	[NumberofTerms] [int] NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsExcludeFeeApplicable] [bit] NOT NULL,
	[FeeExclusionExpression] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[ReceivableCodeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[TerminationTypeParameterConfigId] [bigint] NOT NULL,
	[PayOffTemplateTerminationTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
