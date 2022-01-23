SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssumptionSecurityDeposits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransferToNewCustomer_Amount] [decimal](16, 2) NOT NULL,
	[TransferToNewCustomer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BalanceWithOldCustomer_Amount] [decimal](16, 2) NOT NULL,
	[BalanceWithOldCustomer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SecurityDepositId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SecurityDepositAmount_Amount] [decimal](16, 2) NOT NULL,
	[SecurityDepositAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssumptionSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EAssumption_AssumptionSecurityDeposits] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssumptionSecurityDeposits] CHECK CONSTRAINT [EAssumption_AssumptionSecurityDeposits]
GO
ALTER TABLE [dbo].[AssumptionSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EAssumptionSecurityDeposit_SecurityDeposit] FOREIGN KEY([SecurityDepositId])
REFERENCES [dbo].[SecurityDeposits] ([Id])
GO
ALTER TABLE [dbo].[AssumptionSecurityDeposits] CHECK CONSTRAINT [EAssumptionSecurityDeposit_SecurityDeposit]
GO
