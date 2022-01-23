SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeveragedLeaseContractOptions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractOption] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractOptionTerms] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsEarly] [bit] NOT NULL,
	[IsAnyDay] [bit] NOT NULL,
	[OptionDate] [date] NULL,
	[PurchaseFactor] [decimal](8, 4) NULL,
	[RenewalFactor] [decimal](8, 4) NULL,
	[Penalty] [decimal](5, 2) NULL,
	[IsPartialPermitted] [bit] NOT NULL,
	[IsExcluded] [bit] NOT NULL,
	[IsRenewalOfferApproved] [bit] NOT NULL,
	[LesseeNoticeDays] [int] NULL,
	[RestockingFee] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeveragedLeaseId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeveragedLeaseContractOptions]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_LeveragedLeaseContractOptions] FOREIGN KEY([LeveragedLeaseId])
REFERENCES [dbo].[LeveragedLeases] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeveragedLeaseContractOptions] CHECK CONSTRAINT [ELeveragedLease_LeveragedLeaseContractOptions]
GO
