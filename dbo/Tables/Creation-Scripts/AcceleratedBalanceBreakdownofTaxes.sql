SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcceleratedBalanceBreakdownofTaxes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Header] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxPercent] [decimal](9, 6) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
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
ALTER TABLE [dbo].[AcceleratedBalanceBreakdownofTaxes]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceBreakdownofTaxes] FOREIGN KEY([AcceleratedBalanceDetailId])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AcceleratedBalanceBreakdownofTaxes] CHECK CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceBreakdownofTaxes]
GO
