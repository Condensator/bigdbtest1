SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Discountings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[NonAccrualDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Discountings]  WITH CHECK ADD  CONSTRAINT [EDiscounting_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[Discountings] CHECK CONSTRAINT [EDiscounting_Currency]
GO
