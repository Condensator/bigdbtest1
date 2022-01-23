SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InterestRateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsFloatRate] [bit] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[BaseRate] [decimal](12, 6) NOT NULL,
	[Spread] [decimal](12, 6) NOT NULL,
	[InterestRate] [decimal](12, 6) NOT NULL,
	[FloorPercent] [decimal](10, 6) NOT NULL,
	[CeilingPercent] [decimal](10, 6) NOT NULL,
	[FloatRateResetFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[FloatRateResetUnit] [int] NOT NULL,
	[FirstResetDate] [date] NULL,
	[CompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[HolidayMoveMethod] [nvarchar](22) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsIndexPercentage] [bit] NOT NULL,
	[PercentageBasis] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[Percentage] [decimal](9, 5) NOT NULL,
	[IsLeadUnitsinBusinessDays] [bit] NOT NULL,
	[LeadFrequency] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[LeadUnits] [int] NOT NULL,
	[EffectiveDayofMonth] [int] NOT NULL,
	[IsMoveAcrossMonth] [bit] NOT NULL,
	[ModificationType] [nvarchar](31) COLLATE Latin1_General_CI_AS NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[BankIndexDescription] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FloatRateIndexId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsHighPrimeInterest] [bit] NOT NULL,
	[IsManualInterestMargin] [bit] NOT NULL,
	[InterestConfiguration] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RateCardInterest] [decimal](10, 6) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InterestRateDetails]  WITH CHECK ADD  CONSTRAINT [EInterestRateDetail_FloatRateIndex] FOREIGN KEY([FloatRateIndexId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[InterestRateDetails] CHECK CONSTRAINT [EInterestRateDetail_FloatRateIndex]
GO
