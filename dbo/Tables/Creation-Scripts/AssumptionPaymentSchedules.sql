SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssumptionPaymentSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Calculate] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[LeasePaymentScheduleId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssumptionPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [EAssumption_AssumptionPaymentSchedules] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssumptionPaymentSchedules] CHECK CONSTRAINT [EAssumption_AssumptionPaymentSchedules]
GO
ALTER TABLE [dbo].[AssumptionPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [EAssumptionPaymentSchedule_LeasePaymentSchedule] FOREIGN KEY([LeasePaymentScheduleId])
REFERENCES [dbo].[LeasePaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[AssumptionPaymentSchedules] CHECK CONSTRAINT [EAssumptionPaymentSchedule_LeasePaymentSchedule]
GO
