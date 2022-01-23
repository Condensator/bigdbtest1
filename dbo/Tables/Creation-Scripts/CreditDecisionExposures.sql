SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditDecisionExposures](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExposureType] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[Direct_Amount] [decimal](24, 2) NOT NULL,
	[Direct_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Indirect_Amount] [decimal](24, 2) NOT NULL,
	[Indirect_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryCustomer_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AsOfDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditDecisionExposures]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_CreditDecisionExposures] FOREIGN KEY([CreditDecisionId])
REFERENCES [dbo].[CreditDecisions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditDecisionExposures] CHECK CONSTRAINT [ECreditDecision_CreditDecisionExposures]
GO
