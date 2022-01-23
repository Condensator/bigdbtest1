SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TerminationTypeParameterConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Label] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Parameter] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Entity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Property] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[DiscountRateApplicable] [bit] NOT NULL,
	[FactorApplicable] [bit] NOT NULL,
	[BlendedItemCodeApplicable] [bit] NOT NULL,
	[SundryCodeApplicable] [bit] NOT NULL,
	[NumberofTermsApplicable] [bit] NOT NULL,
	[OperatorSign] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ApplicableForFixedTerm] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsLease] [bit] NOT NULL,
	[ApplicableForOTP] [bit] NOT NULL,
	[IsApplicableForFeeParameter] [bit] NOT NULL,
	[IsApplicableForPayoffAtMaturity] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
