SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerServiceOrWorkouts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreditWatch] [bit] NOT NULL,
	[Date] [date] NULL,
	[Reason] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerServiceOrWorkouts]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerServiceOrWorkouts] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerServiceOrWorkouts] CHECK CONSTRAINT [ECustomer_CustomerServiceOrWorkouts]
GO
