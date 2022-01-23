SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcceleratedBalancePIHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Asof] [date] NULL,
	[AccruedInterest_Amount] [decimal](16, 2) NULL,
	[AccruedInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PerDiem_Amount] [decimal](16, 2) NULL,
	[PerDiem_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Principal_Amount] [decimal](16, 2) NULL,
	[Principal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalPAndI_Amount] [decimal](16, 2) NULL,
	[TotalPAndI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsLease] [bit] NOT NULL,
	[IsJudgement] [bit] NOT NULL,
	[InterestAccrualDetailRowNo] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[AcceleratedBalancePIHistories]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalancePIHistories] FOREIGN KEY([AcceleratedBalanceDetailId])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AcceleratedBalancePIHistories] CHECK CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalancePIHistories]
GO
