SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractLateFeeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DaysLate] [int] NOT NULL,
	[InterestRate] [decimal](10, 6) NULL,
	[PayPercent] [decimal](10, 6) NULL,
	[FlatFee_Amount] [decimal](16, 2) NULL,
	[FlatFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractLateFeeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractLateFeeDetails]  WITH CHECK ADD  CONSTRAINT [EContractLateFee_ContractLateFeeDetails] FOREIGN KEY([ContractLateFeeId])
REFERENCES [dbo].[ContractLateFees] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractLateFeeDetails] CHECK CONSTRAINT [EContractLateFee_ContractLateFeeDetails]
GO
