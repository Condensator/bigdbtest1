SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcceleratedBalanceExpenses](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExpenseType] [nvarchar](26) COLLATE Latin1_General_CI_AS NOT NULL,
	[Date] [date] NULL,
	[WaivedAmount_Amount] [decimal](16, 2) NOT NULL,
	[WaivedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountDue_Amount] [decimal](16, 2) NOT NULL,
	[AmountDue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsLease] [bit] NOT NULL,
	[IsJudgement] [bit] NOT NULL,
	[Payee] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AcceleratedBalanceDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AcceleratedBalanceExpenses]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceExpenses] FOREIGN KEY([AcceleratedBalanceDetailId])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AcceleratedBalanceExpenses] CHECK CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceExpenses]
GO
