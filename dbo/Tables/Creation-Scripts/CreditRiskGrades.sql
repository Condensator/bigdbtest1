SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditRiskGrades](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Code] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdjustedCode] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[EntryDate] [date] NOT NULL,
	[FinancialStatementDate] [date] NULL,
	[RAID] [int] NULL,
	[IsRatingSubstitution] [bit] NOT NULL,
	[DefaultEvent] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[OverrideParty] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[OverrideRating] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[OverrideRatingDate] [date] NULL,
	[RatingModelId] [bigint] NOT NULL,
	[AdjustmentReasonId] [bigint] NULL,
	[ContractId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditRiskGrades]  WITH CHECK ADD  CONSTRAINT [ECreditRiskGrade_AdjustmentReason] FOREIGN KEY([AdjustmentReasonId])
REFERENCES [dbo].[AdjustmentReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditRiskGrades] CHECK CONSTRAINT [ECreditRiskGrade_AdjustmentReason]
GO
ALTER TABLE [dbo].[CreditRiskGrades]  WITH CHECK ADD  CONSTRAINT [ECreditRiskGrade_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[CreditRiskGrades] CHECK CONSTRAINT [ECreditRiskGrade_Contract]
GO
ALTER TABLE [dbo].[CreditRiskGrades]  WITH CHECK ADD  CONSTRAINT [ECreditRiskGrade_RatingModel] FOREIGN KEY([RatingModelId])
REFERENCES [dbo].[RatingModelConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditRiskGrades] CHECK CONSTRAINT [ECreditRiskGrade_RatingModel]
GO
ALTER TABLE [dbo].[CreditRiskGrades]  WITH CHECK ADD  CONSTRAINT [ECustomer_CreditRiskGrades] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditRiskGrades] CHECK CONSTRAINT [ECustomer_CreditRiskGrades]
GO
