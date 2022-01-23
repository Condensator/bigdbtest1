SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingYields](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveDate] [date] NOT NULL,
	[Yield] [decimal](28, 18) NOT NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingYields]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingYields] FOREIGN KEY([DiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingYields] CHECK CONSTRAINT [EDiscountingFinance_DiscountingYields]
GO
