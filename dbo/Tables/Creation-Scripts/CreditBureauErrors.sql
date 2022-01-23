SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauErrors](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ErrorLevel] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[LoggedDate] [date] NULL,
	[User] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsFromWorkFlow] [bit] NOT NULL,
	[Source] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FICOErrorMessageConfigId] [bigint] NULL,
	[CreditBureauRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauErrors]  WITH CHECK ADD  CONSTRAINT [ECreditBureauError_FICOErrorMessageConfig] FOREIGN KEY([FICOErrorMessageConfigId])
REFERENCES [dbo].[FICOErrorMessageConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauErrors] CHECK CONSTRAINT [ECreditBureauError_FICOErrorMessageConfig]
GO
ALTER TABLE [dbo].[CreditBureauErrors]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRequest_CreditBureauErrors] FOREIGN KEY([CreditBureauRequestId])
REFERENCES [dbo].[CreditBureauRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauErrors] CHECK CONSTRAINT [ECreditBureauRequest_CreditBureauErrors]
GO
