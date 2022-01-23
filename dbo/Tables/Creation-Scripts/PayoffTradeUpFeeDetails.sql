SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffTradeUpFeeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RemainingNumberofMonths] [bigint] NULL,
	[Field1] [decimal](5, 2) NULL,
	[Field2] [decimal](5, 2) NULL,
	[Field3] [decimal](5, 2) NULL,
	[Field4] [decimal](5, 2) NULL,
	[Field5] [decimal](5, 2) NULL,
	[Field6] [decimal](5, 2) NULL,
	[Field7] [decimal](5, 2) NULL,
	[Field8] [decimal](5, 2) NULL,
	[Field9] [decimal](5, 2) NULL,
	[Field10] [decimal](5, 2) NULL,
	[IsHeaderRecord] [bit] NOT NULL,
	[NumberOfColumns] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayoffTradeUpFeeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffTradeUpFeeDetails]  WITH CHECK ADD  CONSTRAINT [EPayoffTradeUpFee_PayoffTradeUpFeeDetails] FOREIGN KEY([PayoffTradeUpFeeId])
REFERENCES [dbo].[PayoffTradeUpFees] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffTradeUpFeeDetails] CHECK CONSTRAINT [EPayoffTradeUpFee_PayoffTradeUpFeeDetails]
GO
