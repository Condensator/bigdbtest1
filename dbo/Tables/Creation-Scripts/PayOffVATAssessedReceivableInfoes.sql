SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayOffVATAssessedReceivableInfoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DueDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAmount_Amount] [decimal](16, 2) NOT NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableType] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PayoffId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayOffVATAssessedReceivableInfoes]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayOffVATAssessedReceivableInfoes] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayOffVATAssessedReceivableInfoes] CHECK CONSTRAINT [EPayoff_PayOffVATAssessedReceivableInfoes]
GO
